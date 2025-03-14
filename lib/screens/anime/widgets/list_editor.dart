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

  const ListEditorModal({
    super.key,
    required this.animeStatus,
    required this.animeScore,
    required this.animeProgress,
    required this.currentAnime,
    required this.media,
    required this.onUpdate,
    required this.onDelete,
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
    final TextEditingController controller = TextEditingController();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          controller.text = animeProgress.value.toString();
          return Expanded(
            child: SizedBox(
                height: 55,
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: controller,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.add),
                    suffixText: '${animeProgress.value}/${media.totalEpisodes}',
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
                    labelText: 'Progress',
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins-Bold',
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (String value) {
                    int? newProgress = int.tryParse(value);
                    if (newProgress != null && newProgress >= 0) {
                      if (media.totalEpisodes == '?') {
                        animeProgress.value = newProgress;
                      } else {
                        int totalEp = int.tryParse(media.totalEpisodes) ?? 9999;
                        animeProgress.value =
                            newProgress <= totalEp ? newProgress : totalEp;
                      }
                    }
                  },
                )),
          );
        }),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (animeProgress.value <
                (int.tryParse(media.totalEpisodes ?? '9999') ?? 9999)) {
              animeProgress.value++;
            }
          },
          child: Container(
            width: 55,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const AnymexText(
              text: "+1",
              variant: TextVariant.semiBold,
            ),
          ),
        )
      ],
    );
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
