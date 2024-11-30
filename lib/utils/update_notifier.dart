import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkForUpdate(context) async {
  try {
    final response = await http.get(Uri.parse(
        'https://api.github.com/repos/RyanYuuki/AnymeX/releases/latest'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String latestVersion = data['tag_name'];
      String changelog = data['body'];
      String releaseTitle = data['name'];

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        _showUpdateBottomSheet(context, changelog, releaseTitle);
      }
    }
  } catch (e) {
    log('Error checking for updates: $e');
  }
}

bool _isNewerVersion(String currentVersion, String latestVersion) {
  currentVersion = currentVersion.replaceFirst('v', '');
  latestVersion = latestVersion.replaceFirst('v', '');

  currentVersion = currentVersion.replaceAll(RegExp(r'-.*'), '');
  latestVersion = latestVersion.replaceAll(RegExp(r'-.*'), '');

  List<int> current = currentVersion.split('.').map(int.parse).toList();
  List<int> latest = latestVersion.split('.').map(int.parse).toList();

  for (int i = 0; i < current.length; i++) {
    if (latest[i] > current[i]) return true;
  }

  return false;
}

Future<void> launchUrlHelper(String link) async {
  final url = Uri.parse(link);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $link';
  }
}

void _showUpdateBottomSheet(
  BuildContext context,
  String changelog,
  String name,
) {
  Map<String, List<String>> parsedChanges = _parseChangelog(changelog);
  List<String> headers = parsedChanges.keys.toList();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Update Available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontFamily: 'Poppins-SemiBold'),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: headers.map((header) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                header.replaceAll('**', '').replaceAll('##', ''),
                                style: const TextStyle(
                                  fontFamily: 'Poppins-SemiBold',
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: parsedChanges[header]?.length ?? 0,
                            itemBuilder: (context, index) {
                              final change = parsedChanges[header]![index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 20, top: 5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(top: 5, right: 8),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        change.split(':').last,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 15),
            const Divider(thickness: 1),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.primary))),
                    child: const Text(
                      'Cancel',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      launchUrl(Uri.parse(
                          'https://github.com/RyanYuuki/AnymeX/releases/latest'));
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black),
                    child: const Text('Update'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Map<String, List<String>> _parseChangelog(String changelog) {
  Map<String, List<String>> parsedChanges = {};
  List<String> sections =
      changelog.split(RegExp(r'(?<=\r\n)\*\*[^*]+(?=\*\*)'));

  for (var section in sections) {
    if (section.trim().isEmpty) continue;

    List<String> lines =
        section.split('\r\n').where((line) => line.isNotEmpty).toList();
    String header = lines.first.trim();
    List<String> body = lines.sublist(1).map((e) => e.trim()).toList();

    parsedChanges[header] = body;
  }

  return parsedChanges;
}
