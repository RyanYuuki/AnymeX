import 'package:anymex/utils/function.dart';
import 'package:anymex/widgets/common/glow.dart';
import 'package:anymex/widgets/helper/platform_builder.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:uuid/uuid.dart';

class SettingsAniSkipContribute extends StatefulWidget {
  const SettingsAniSkipContribute({super.key});

  @override
  State<SettingsAniSkipContribute> createState() => _SettingsAniSkipContributeState();
}

class _SettingsAniSkipContributeState extends State<SettingsAniSkipContribute> {
  final TextEditingController malIdController = TextEditingController();
  final TextEditingController episodeNumberController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController episodeLengthController = TextEditingController();
  String? selectedSkipType;
  bool isSubmitting = false;
  String? submitStatus;

  final List<String> skipTypes = ['op', 'ed', 'recap', 'mixed-op', 'mixed-ed'];

  Future<void> submitSkipTime() async {
    if (malIdController.text.isEmpty ||
        episodeNumberController.text.isEmpty ||
        startTimeController.text.isEmpty ||
        endTimeController.text.isEmpty ||
        episodeLengthController.text.isEmpty ||
        selectedSkipType == null) {
      setState(() {
        submitStatus = 'Please fill all fields';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
      submitStatus = null;
    });

    try {
      final int malId = int.parse(malIdController.text);
      final double episodeNumber = double.parse(episodeNumberController.text);
      final int startTime = int.parse(startTimeController.text);
      final int endTime = int.parse(endTimeController.text);
      final int episodeLength = int.parse(episodeLengthController.text);

      if (startTime >= endTime) {
        setState(() {
          submitStatus = 'Start time must be less than end time';
          isSubmitting = false;
        });
        return;
      }

      if (endTime > episodeLength) {
        setState(() {
          submitStatus = 'End time cannot exceed episode length';
          isSubmitting = false;
        });
        return;
      }

      final uuid = const Uuid().v4();

      final Map<String, dynamic> requestBody = {
        'skipType': selectedSkipType,
        'providerName': 'AnymeX',
        'startTime': startTime,
        'endTime': endTime,
        'episodeLength': episodeLength,
        'submitterId': uuid,
      };

      final response = await http.post(
        Uri.parse('https://api.aniskip.com/v2/skip-times/$malId/$episodeNumber'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          submitStatus = 'Successfully submitted! Skip ID: ${responseData['skipId']}';
          malIdController.clear();
          episodeNumberController.clear();
          startTimeController.clear();
          endTimeController.clear();
          episodeLengthController.clear();
          selectedSkipType = null;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          submitStatus = 'Error: ${response.statusCode} - ${errorData['message'] ?? errorData}';
        });
      }
    } catch (e) {
      setState(() {
        submitStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainer;

    return Glow(
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Contribute Skip Times',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SuperListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Submit Skip Times to AniSkip Database',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: backgroundColor,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MAL ID'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: malIdController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g., 21 for One Piece',
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Episode Number'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: episodeNumberController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g., 1155',
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Skip Type'),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: selectedSkipType,
                                  hint: const Text('Select skip type'),
                                  items: skipTypes.map((type) {
                                    String displayText;
                                    switch (type) {
                                      case 'op':
                                        displayText = 'Opening (OP)';
                                        break;
                                      case 'ed':
                                        displayText = 'Ending (ED)';
                                        break;
                                      case 'recap':
                                        displayText = 'Recap';
                                        break;
                                      case 'mixed-op':
                                        displayText = 'Mixed Opening';
                                        break;
                                      case 'mixed-ed':
                                        displayText = 'Mixed Ending';
                                        break;
                                      default:
                                        displayText = type;
                                    }
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(displayText),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSkipType = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Start Time (seconds)'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: startTimeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g., 90 for 1:30',
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('End Time (seconds)'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: endTimeController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g., 150 for 2:30',
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Episode Length (seconds)'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: episodeLengthController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'e.g., 1440 for 24 minutes',
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (submitStatus != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    submitStatus!,
                                    style: TextStyle(
                                      color: submitStatus!.startsWith('Success') 
                                          ? Colors.green 
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isSubmitting ? null : submitSkipTime,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Submit Skip Time'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: backgroundColor,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text('• Find the MAL ID from MyAnimeList.net'),
                          Text('• Time values should be in seconds'),
                          Text('• OP = Opening, ED = Ending, Recap = Previous episode summary'),
                          Text('• Mixed-OP/ED = Opening/Ending with additional content'),
                          Text('• Make sure times are accurate before submitting'),
                          SizedBox(height: 8),
                          Text(
                            'Note: Your submissions help improve the skip feature for everyone!',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
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